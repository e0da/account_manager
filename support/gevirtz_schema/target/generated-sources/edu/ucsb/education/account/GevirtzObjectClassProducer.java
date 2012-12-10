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
import org.apache.directory.shared.ldap.schema.ObjectClassTypeEnum;

import org.apache.directory.server.core.schema.bootstrap.*;

/**
 * A producer of schema objectClass definations for the gevirtz schema.  This
 * code has been automatically generated using schema files in the OpenLDAP
 * format along with the directory plugin for maven.  This has been done
 * to facilitate OpenLDAP schema interoperability.
 *
 * @author <a href="mailto:dev@directory.apache.org">Apache Directory Project</a>
 * @version $Rev$
 */
public class GevirtzObjectClassProducer extends AbstractBootstrapProducer
{

    public GevirtzObjectClassProducer()
    {
        super( ProducerTypeEnum.OBJECT_CLASS_PRODUCER );
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
        ArrayList array = new ArrayList();
        BootstrapObjectClass objectClass;

        
        // --------------------------------------------------------------------
        // ObjectClass 1.3.6.1.4.1.18060.0.4.1.3.1001 
        // --------------------------------------------------------------------

        objectClass = newObjectClass( "1.3.6.1.4.1.18060.0.4.1.3.1001", registries );
        objectClass.setObsolete( false );

        objectClass.setDescription( "ggseperson" );
        // set the objectclass type
        objectClass.setType( ObjectClassTypeEnum.STRUCTURAL );
        
        // set superior objectClasses
        array.clear();
        array.add( "person" );
        objectClass.setSuperClassIds( ( String[] ) array.toArray( EMPTY ) );
        
        // set must list
        array.clear();
        objectClass.setMustListIds( ( String[] ) array.toArray( EMPTY ) );
        
        // set may list
        array.clear();
        array.add( "ituseagreementacceptdate" );
        array.add( "passwordchangedate" );
        array.add( "nsroledn" );
        array.add( "nsaccountlock" );
        array.add( "mailforwardingaddress" );
        objectClass.setMayListIds( ( String[] ) array.toArray( EMPTY ) );
        
        // set names
        array.clear();
        array.add( "ggseperson" );
        objectClass.setNames( ( String[] ) array.toArray( EMPTY ) );
        cb.schemaObjectProduced( this, "1.3.6.1.4.1.18060.0.4.1.3.1001", objectClass );

    }
}
