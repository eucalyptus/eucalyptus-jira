/*************************************************************************
 * Copyright 2009-2015 Eucalyptus Systems, Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see http://www.gnu.org/licenses/.
 *
 * Please contact Eucalyptus Systems, Inc., 6755 Hollister Ave., Goleta
 * CA 93117, USA or visit http://www.eucalyptus.com/licenses/ if you need
 * additional information or have any questions.
 ************************************************************************/
package com.eucalyptus.tests.awssdk

import com.amazonaws.AmazonServiceException
import com.amazonaws.auth.AWSCredentialsProvider
import com.amazonaws.auth.BasicAWSCredentials
import com.amazonaws.handlers.AbstractRequestHandler
import com.amazonaws.internal.StaticCredentialsProvider
import com.amazonaws.regions.Region
import com.amazonaws.regions.Regions
import com.amazonaws.services.identitymanagement.model.CreateAccountAliasRequest
import com.amazonaws.services.identitymanagement.model.CreateGroupRequest
import com.amazonaws.services.identitymanagement.model.CreateInstanceProfileRequest
import com.amazonaws.services.identitymanagement.model.CreateLoginProfileRequest
import com.amazonaws.services.identitymanagement.model.CreateRoleRequest
import com.amazonaws.services.identitymanagement.model.CreateUserRequest
import com.amazonaws.services.identitymanagement.model.DeleteGroupRequest
import com.amazonaws.services.identitymanagement.model.DeleteInstanceProfileRequest
import com.amazonaws.services.identitymanagement.model.DeleteLoginProfileRequest
import com.amazonaws.services.identitymanagement.model.DeleteRoleRequest
import com.amazonaws.services.identitymanagement.model.DeleteUserPolicyRequest
import com.amazonaws.services.identitymanagement.model.DeleteUserRequest
import com.amazonaws.services.identitymanagement.model.NoSuchEntityException
import com.amazonaws.services.identitymanagement.model.PutUserPolicyRequest
import com.github.sjones4.youcan.youare.YouAreClient

/**
 * Tests name limits for IAM resources.
 *
 * Related issue:
 *   https://eucalyptus.atlassian.net/browse/EUCA-8971
 *
 * Related AWS doc:
 *   http://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html
 *   
 */
class TestIAMLimits {
  
  private final String host = '10.111.X.XXX'

  private final AWSCredentialsProvider credentials = new StaticCredentialsProvider( new BasicAWSCredentials(
      'AKI...',
      '...'
  ) )

  public static void main( String[] args ) throws Exception {
    new TestIAMLimits( ).test( )
  }

  private String cloudUri( String host, String servicePath ) {
    URI.create( "http://${host}:8773/" )
        .resolve( servicePath )
        .toString( )
  }

  private YouAreClient getYouAreClient( final String host, final AWSCredentialsProvider credentials  ) {
    final YouAreClient euare = new YouAreClient( credentials )
    if ( host ) {
      euare.setEndpoint( cloudUri( host, '/services/Euare' ) )
    } else {
      euare.setRegion( Region.getRegion( Regions.US_EAST_1 ) )
    }
    euare
  }

  private boolean assertThat( boolean condition,
                              String message ){
    assert condition : message
    true
  }

  private void print( String text ) {
    System.out.println( text )
  }

  public void test() throws Exception {
    final String namePrefix = UUID.randomUUID().toString().substring(0,8) + "-"
    print( "Using resource prefix for test: ${namePrefix}" )

    final List<Runnable> cleanupTasks = [] as List<Runnable>
    try {
      getYouAreClient( host, credentials ).with {
        String userName = "${namePrefix}user1"
        cleanupTasks.add{
          println( "Deleting user ${userName}" )
          deleteUser( new DeleteUserRequest(
              userName: userName
          ) )
        }
        print( "Creating user ${userName} with invalid (long) path" )
        try {
          createUser( new CreateUserRequest(
              userName: userName,
              path: "/${'a'.multiply(512)}/"
          ) )
          assertThat( false, 'Expected user creation failure due to invalid path' )
        } catch ( AmazonServiceException e ) {
          print( "Exception for invalid path : ${e}" )
          assertThat( 'ValidationError' == e.errorCode, "Expected ValidationError, but was ${e.errorCode}" )
        }

        String userNameLong = "${userName}${'a'.multiply(64)}"
        print( "Creating user ${userNameLong} with invalid (long) name" )
        try {
          createUser( new CreateUserRequest(
              userName: userNameLong,
              path: '/'
          ) )
          cleanupTasks.add{
            println( "Deleting user ${userNameLong}" )
            deleteUser( new DeleteUserRequest(
                userName: userNameLong
            ) )
          }
          assertThat( false, 'Expected user creation failure due to invalid name' )
        } catch ( AmazonServiceException e ) {
          print( "Exception for invalid user name : ${e}" )
          assertThat( 'ValidationError' == e.errorCode, "Expected ValidationError, but was ${e.errorCode}" )
        }

        print( "Creating user ${userName}" )
        createUser( new CreateUserRequest(
            userName: userName,
            path: '/'
        ) )

        String groupName = "${namePrefix}group1"
        String groupNameLong = "${groupName}${'a'.multiply(128)}"
        print( "Creating group ${groupNameLong} with invalid (long) name" )
        try {
          createGroup( new CreateGroupRequest(
              groupName: groupNameLong,
              path: '/'
          ) )
          cleanupTasks.add{
            println( "Deleting group ${groupNameLong}" )
            deleteGroup( new DeleteGroupRequest(
                groupName: groupNameLong
            ) )
          }
          assertThat( false, 'Expected group creation failure due to invalid name' )
        } catch ( AmazonServiceException e ) {
          print( "Exception for invalid group name : ${e}" )
          assertThat( 'ValidationError' == e.errorCode, "Expected ValidationError, but was ${e.errorCode}" )
        }

        print( "Creating group ${groupName}" )
        createGroup( new CreateGroupRequest(
            groupName: groupName,
            path: '/'
        ) )
        cleanupTasks.add{
          println( "Deleting group ${groupName}" )
          deleteGroup( new DeleteGroupRequest(
              groupName: groupName
          ) )
        }

        String roleName = "${namePrefix}role1"
        String roleNameLong = "${roleName}${'a'.multiply(64)}"
        print( "Creating role ${roleNameLong} with invalid (long) name" )
        try {
          createRole( new CreateRoleRequest(
              roleName: roleNameLong,
              path: '/',
              assumeRolePolicyDocument: """\
                {
                    "Statement": [ {
                      "Effect": "Allow",
                      "Principal": {
                         "Service": [ "ec2.amazonaws.com" ]
                      },
                      "Action": [ "sts:AssumeRole" ]
                    } ]
                }
                """.stripIndent( )
          ) )
          cleanupTasks.add{
            println( "Deleting group ${groupNameLong}" )
            deleteGroup( new DeleteGroupRequest(
                groupName: groupNameLong
            ) )
          }
          assertThat( false, 'Expected group creation failure due to invalid name' )
        } catch ( AmazonServiceException e ) {
          print( "Exception for invalid group name : ${e}" )
          assertThat( 'ValidationError' == e.errorCode, "Expected ValidationError, but was ${e.errorCode}" )
        }        
        
        print( "Creating role ${roleName}" )
        createRole( new CreateRoleRequest(
            roleName: roleName,
            path: '/',
            assumeRolePolicyDocument: """\
            {
                "Statement": [ {
                  "Effect": "Allow",
                  "Principal": {
                     "Service": [ "ec2.amazonaws.com" ]
                  },
                  "Action": [ "sts:AssumeRole" ]
                } ]
            }
            """.stripIndent( )
        ) )
        cleanupTasks.add{
          println( "Deleting role ${roleName}" )
          deleteRole( new DeleteRoleRequest(
              roleName: roleName
          ) )
        }

        String instanceProfileName = "${namePrefix}instance-profile1"
        String instanceProfileNameLong = "${instanceProfileName}${'a'.multiply(128)}"
        print( "Creating instance profile ${instanceProfileNameLong} with invalid (long) name" )
        try {
          createInstanceProfile( new CreateInstanceProfileRequest(
              instanceProfileName: instanceProfileNameLong,
              path: '/'
          ) )
          cleanupTasks.add{
            println( "Deleting instance profile ${instanceProfileNameLong}" )
            deleteInstanceProfile( new DeleteInstanceProfileRequest(
                instanceProfileName: instanceProfileNameLong
            ) )
          }
          assertThat( false, 'Expected instance profile creation failure due to invalid name' )
        } catch ( AmazonServiceException e ) {
          print( "Exception for invalid instance profile name : ${e}" )
          assertThat( 'ValidationError' == e.errorCode, "Expected ValidationError, but was ${e.errorCode}" )
        }
        
        print( "Creating instance profile ${instanceProfileName}" )
        createInstanceProfile( new CreateInstanceProfileRequest(
            instanceProfileName: instanceProfileName,
            path: '/'
        ) )
        cleanupTasks.add{
          println( "Deleting instance profile ${instanceProfileName}" )
          deleteInstanceProfile( new DeleteInstanceProfileRequest(
              instanceProfileName: instanceProfileName
          ) )
        }

        String policyName = "${namePrefix}policy1"
        String policyNameLong = "${policyName}${'a'.multiply(128)}"
        print( "Creating user policy ${policyNameLong} with invalid (long) name" )
        try {
          putUserPolicy( new PutUserPolicyRequest(
              userName: userName,
              policyName: policyNameLong,
              policyDocument: '''\
              {
                 "Statement":[{
                    "Effect":"Allow",
                    "Action":"ec2:*",
                    "Resource":"*"
                 }]
              }
              '''.stripIndent( )
          ) )
          cleanupTasks.add{
            print( "Deleting user policy ${policyNameLong}" )
            deleteUserPolicy( new DeleteUserPolicyRequest(
                userName: userName,
                policyName: policyNameLong
            ) )
          }
          assertThat( false, 'Expected user policy creation failure due to invalid name' )
        } catch ( AmazonServiceException e ) {
          print( "Exception for invalid policy name : ${e}" )
          assertThat( 'ValidationError' == e.errorCode, "Expected ValidationError, but was ${e.errorCode}" )
        }        
        
        print( "Creating user policy ${policyName}" )
        putUserPolicy( new PutUserPolicyRequest(
            userName: userName,
            policyName: policyName,
            policyDocument: '''\
              {
                 "Statement":[{
                    "Effect":"Allow",
                    "Action":"ec2:*",
                    "Resource":"*"
                 }]
              }
              '''.stripIndent( )
        ) )
        cleanupTasks.add{
          print( "Deleting user policy ${policyName}" )
          deleteUserPolicy( new DeleteUserPolicyRequest(
              userName: userName,
              policyName: policyName
          ) )
        }
        
        cleanupTasks.add{
          print( "Deleting login profile for user" )
          deleteLoginProfile( new DeleteLoginProfileRequest(
              userName: userName
          ) )
        }
        print( "Creating login profile for user with invalid (long) password" )
        try {
          createLoginProfile( new CreateLoginProfileRequest(
              userName: userName,
              password: "aA1-${'a'.multiply(128)}"
          ) )
          assertThat( false, 'Expected login profile creation failure due to invalid password' )
        } catch ( AmazonServiceException e ) {
          print( "Exception for invalid password : ${e}" )
          assertThat( 'ValidationError' == e.errorCode, "Expected ValidationError, but was ${e.errorCode}" )
        }

        print( "Creating login profile for user" )
        createLoginProfile( new CreateLoginProfileRequest(
            userName: userName,
            password: "aA1-${'a'.multiply(32)}"
        ) )
        
        println( "Setting invalid (long) alias for account" )
        try {
          createAccountAlias( new CreateAccountAliasRequest(
              accountAlias: "${namePrefix}${'a'.multiply(63)}"
          ) )
          assertThat( false, 'Expected account alias creation failure due to invalid alias' )
        } catch ( AmazonServiceException e ) {
          print( "Exception for invalid account alias : ${e}" )
          assertThat( 'ValidationError' == e.errorCode, "Expected ValidationError, but was ${e.errorCode}" )
        }
        
        print( "Sleeping to allow resource creation to complete ..." )
        sleep( 30000 )
      }

      print( "Test complete" )
    } finally {
      // Attempt to clean up anything we created
      cleanupTasks.reverseEach { Runnable cleanupTask ->
        try {
          cleanupTask.run()
        } catch ( NoSuchEntityException e ) {
          print( "Entity not found during cleanup." )
        } catch ( AmazonServiceException e ) {
          print( "Service error during cleanup; code: ${e.errorCode}, message: ${e.message}" )
        } catch ( Exception e ) {
          e.printStackTrace()
        }
      }
    }
  }  
}
