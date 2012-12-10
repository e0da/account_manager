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


import org.apache.directory.server.core.schema.bootstrap.*;


/**
 * Top level gevirtz schema class.  This code has been automatically generated
 * using the directory plugin for maven.
 *
 * @author <a href="mailto:dev@directory.apache.org">Apache Directory Project</a>
 * @version $Rev$
 */
public class GevirtzSchema extends AbstractBootstrapSchema
{
    public GevirtzSchema()
    {
        super( "uid=admin,ou=system", "gevirtz", "edu.ucsb.education.account" );

        ArrayList list = new ArrayList();
        list.clear();
        list.add( "system" );
        list.add( "core" );
        setDependencies( ( String[] ) list.toArray( DEFAULT_DEPS ) );
    }
}
