/*
 *  Licensed to the Apache Software Foundation (ASF) under one
 *  or more contributor license agreements.  See the NOTICE file
 *  distributed with this work for additional information
 *  regarding copyright ownership.  The ASF licenses this file
 *  to you under the Apache License, Version 2.0 (the
 *  "License"); you may not use this file except in compliance
 *  with the License.  You may obtain a copy of the License at
 *  
 *    http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License. 
 *  
 */
package edu.ucsb.education.account;


import java.util.ArrayList;
import javax.naming.NamingException;

import org.apache.directory.shared.ldap.schema.*;

import org.apache.directory.server.core.schema.bootstrap.*;

/**
 * A producer of schema attributeType definations for the gevirtz schema.  This
 * code has been automatically generated using schema files in the OpenLDAP
 * format along with the directory plugin for maven.  This has been done
 * to facilitate Eve<->OpenLDAP schema interoperability.
 *
 * @author <a href="mailto:dev@directory.apache.org">Apache Directory Project</a>
 * @version $Rev$
 */
public class GevirtzAttributeTypeProducer extends AbstractBootstrapProducer
{

    public GevirtzAttributeTypeProducer()
    {
        super( ProducerTypeEnum.ATTRIBUTE_TYPE_PRODUCER );
    }


    // ------------------------------------------------------------------------
    // BootstrapProducer Methods
    // ------------------------------------------------------------------------


    /**
     * @see BootstrapProducer#produce(BootstrapRegistries, ProducerCallback)
     */
    public void produce( BootstrapRegistries registries, ProducerCallback cb )
        throws NamingException
    {
        ArrayList names = new ArrayList();
        BootstrapAttributeType attributeType;

        
        // --------------------------------------------------------------------
        // AttributeType 1.3.6.1.4.1.18060.0.4.1.2.1001 
        // --------------------------------------------------------------------

        attributeType = newAttributeType( "1.3.6.1.4.1.18060.0.4.1.2.1001", registries );
        attributeType.setDescription( "ituseagreementacceptdate" );
        attributeType.setCanUserModify( ! false );
        attributeType.setSingleValue( true );
        attributeType.setCollective( false );
        attributeType.setObsolete( false );
        attributeType.setLength( -1 );
        attributeType.setUsage( UsageEnum.getUsage( "userApplications" ) );
        attributeType.setSyntaxId( "1.3.6.1.4.1.1466.115.121.1.24" );
        names.clear();
        names.add( "ituseagreementacceptdate" );
        attributeType.setNames( ( String[] ) names.toArray( EMPTY ) );
        cb.schemaObjectProduced( this, "1.3.6.1.4.1.18060.0.4.1.2.1001", attributeType );

 
        // --------------------------------------------------------------------
        // AttributeType 1.3.6.1.4.1.18060.0.4.1.2.1002 
        // --------------------------------------------------------------------

        attributeType = newAttributeType( "1.3.6.1.4.1.18060.0.4.1.2.1002", registries );
        attributeType.setDescription( "Password reset TimeStamp" );
        attributeType.setCanUserModify( ! false );
        attributeType.setSingleValue( false );
        attributeType.setCollective( false );
        attributeType.setObsolete( false );
        attributeType.setLength( -1 );
        attributeType.setUsage( UsageEnum.getUsage( "userApplications" ) );
        attributeType.setSyntaxId( "1.3.6.1.4.1.1466.115.121.1.15" );
        names.clear();
        names.add( "passwordchangedate" );
        attributeType.setNames( ( String[] ) names.toArray( EMPTY ) );
        cb.schemaObjectProduced( this, "1.3.6.1.4.1.18060.0.4.1.2.1002", attributeType );

 
        // --------------------------------------------------------------------
        // AttributeType 1.3.6.1.4.1.18060.0.4.1.2.1003 
        // --------------------------------------------------------------------

        attributeType = newAttributeType( "1.3.6.1.4.1.18060.0.4.1.2.1003", registries );
        attributeType.setDescription( "Sun ONE defined attribute type" );
        attributeType.setCanUserModify( ! false );
        attributeType.setSingleValue( false );
        attributeType.setCollective( false );
        attributeType.setObsolete( false );
        attributeType.setLength( -1 );
        attributeType.setUsage( UsageEnum.getUsage( "userApplications" ) );
        attributeType.setSyntaxId( "1.3.6.1.4.1.1466.115.121.1.12" );
        names.clear();
        names.add( "nsroledn" );
        attributeType.setNames( ( String[] ) names.toArray( EMPTY ) );
        cb.schemaObjectProduced( this, "1.3.6.1.4.1.18060.0.4.1.2.1003", attributeType );

 
        // --------------------------------------------------------------------
        // AttributeType 1.3.6.1.4.1.18060.0.4.1.2.1004 
        // --------------------------------------------------------------------

        attributeType = newAttributeType( "1.3.6.1.4.1.18060.0.4.1.2.1004", registries );
        attributeType.setDescription( "Operational attribute for Account Inactivation" );
        attributeType.setCanUserModify( ! false );
        attributeType.setSingleValue( false );
        attributeType.setCollective( false );
        attributeType.setObsolete( false );
        attributeType.setLength( -1 );
        attributeType.setUsage( UsageEnum.getUsage( "userApplications" ) );
        attributeType.setSyntaxId( "1.3.6.1.4.1.1466.115.121.1.15" );
        names.clear();
        names.add( "nsaccountlock" );
        attributeType.setNames( ( String[] ) names.toArray( EMPTY ) );
        cb.schemaObjectProduced( this, "1.3.6.1.4.1.18060.0.4.1.2.1004", attributeType );

 
        // --------------------------------------------------------------------
        // AttributeType 1.3.6.1.4.1.18060.0.4.1.2.1005 
        // --------------------------------------------------------------------

        attributeType = newAttributeType( "1.3.6.1.4.1.18060.0.4.1.2.1005", registries );
        attributeType.setDescription( "Mail forwarding address" );
        attributeType.setCanUserModify( ! false );
        attributeType.setSingleValue( false );
        attributeType.setCollective( false );
        attributeType.setObsolete( false );
        attributeType.setLength( -1 );
        attributeType.setUsage( UsageEnum.getUsage( "userApplications" ) );
        attributeType.setSyntaxId( "1.3.6.1.4.1.1466.115.121.1.15" );
        names.clear();
        names.add( "mailforwardingaddress" );
        attributeType.setNames( ( String[] ) names.toArray( EMPTY ) );
        cb.schemaObjectProduced( this, "1.3.6.1.4.1.18060.0.4.1.2.1005", attributeType );

    }
}
