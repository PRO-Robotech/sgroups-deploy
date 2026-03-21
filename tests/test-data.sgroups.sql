BEGIN;
    INSERT INTO sgroups.tbl_namespace(name, uid, display_name, comment, description, labels, annotations, resource_version)
    VALUES
        (
            'namespace-0',
            '368240f3-4866-4cbf-ad3f-6c55b48d4b92',
             '',
            '',
            '',
            'search => both',
            'search => both',
            '1'
        ),
        (
            'namespace-1',
            '82874cc8-0711-40fa-be42-dd480c4cb550',
            '',
            '',
            '',
            'search => labels',
            '',
            '1'
        ),
        (
            'namespace-2',
            '82040ed0-a028-4199-b266-3349096b5376',
            '',
            '',
            '',
            'labels => search',
            '',
            '1'
        ),
        (
            'namespace-3',
            'cd3e3c34-bf87-4787-87e8-7ba7182280c3',
            '',
            '',
            '',
            '',
            '',
            '1'
        ),
        (
            'namespace-4',
            'ccc9c066-2e2d-44aa-9c79-2b2ee0fabcc0',
            '',
            '',
            '',
            '',
            '',
            '1'
        ),
        (
            'namespace-5',
            '1e7c1f61-c021-4e53-8d53-79ee323264b9',
            '',
            '',
            '',
            '',
            '',
            '1'
        );

    INSERT INTO sgroups.tbl_ag(name, uid, ns, logs, trace, default_action, display_name, comment, description, labels, annotations, resource_version)
    VALUES
        (
            'ag-0',
            'd459b92b-0881-4166-9035-6b994ebdf798',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-0'),
            true,
            true,
            'DENY',
            'Address Group',
            'for search by name/ns',
            'address group for search',
            'labels => search',
            'search => labels',
            '1'
        ),
        (
            'ag-1',
            '37817691-8a8b-4344-8593-8a78ec3ce329',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            false,
            false,
            'ALLOW',
            'Address Group 1',
            'for search by name+ns',
            'address group for search',
            'labels => ns',
            'search => name',
            '1'
        ),
        (
            'ag-2',
            'ce6a67d4-c2fa-484f-ae74-85fcd9e65a21',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-2'),
            false,
            true,
            'DENY',
            'Address Group 2',
            'for search by labels',
            'address group for search labels',
            'search => nameLabels',
            '',
            '1'
        ),
        (
            'ag-3',
            '9e9fb305-80bd-4748-ac42-fc208c398220',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            false,
            false,
            'ALLOW',
            'Address Group 3',
            'for edit',
            'address group for edit',
            'edit => ag',
            '',
            '1'
        ),
        (
            'ag-4',
            '596bbfe0-27ba-44f3-b460-99fab561d899',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            true,
            true,
            'ALLOW',
            'Address Group 4',
            'for delete ns+name',
            'address group for delete',
            'delete => name',
            '',
            '1'
        ),
        (
            'ag-5',
            '5cf8ec0d-5d62-472b-9287-6dbcedd87ead',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            true,
            true,
            'ALLOW',
            'Address Group 5',
            'for delete uid',
            'address group for delete',
            'delete => uid',
            '',
            '1'
        ),
        (
            'ag-6',
            'c8ad52a6-8440-4605-b90f-1441d11f3c79',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            true,
            true,
            'ALLOW',
            'Address Group 6',
            'for hb',
            'address group for host binding',
            'host => bind',
            '',
            '1'
        ),
        (
            'ag-7',
            'e225ec25-d4cf-42f8-8ea4-3adbcb02da49',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            true,
            true,
            'ALLOW',
            'Address Group 7',
            'for hb',
            'address group for host binding',
            'host => bind',
            '',
            '1'
        );

    INSERT INTO sgroups.tbl_host(name, uid, ns, ips, meta_info, display_name, comment, description, labels, annotations, resource_version)
    VALUES
        (
            'host-0',
            'c38a4cb9-5689-41c2-9740-feeaa86a1b2e',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-0'),
            '{192.168.1.1, 2001:db8::1}',
            '(host-0, null, null, null, null, null)',
            'host 0',
            'for search by name/ns',
            'host for search',
            'labels => search',
            'search => labels',
            '1'
        ),
        (
            'host-1',
            '013e25da-35bd-4e5f-b3de-5aa9c44564d0',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            '{127.0.0.1, ::1}',
            '(host-1, 1.0, null, null, null, null)',
            'host 1',
            'for search by name/ns',
            'host for search',
            'labels => ns',
            'search => name',
            '1'
        ),
        (
            'host-2',
            '150cb4f9-382b-44e1-b24e-28086f83bbc7',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-2'),
            '{5.5.5.5}',
            '(host-1, 1.0, linux, null, null, null)',
            'host 2',
            'for search by labels',
            'address group for search labels',
            'search => nameLabels',
            '',
            '1'
        ),
        (
            'host-3',
            'f315d9db-691e-4e9c-9bfc-546d59d35a68',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            '{fe80::1}',
            '(host-1, 1.0, linux, ubuntu, null, null)',
            'host 3',
            'for search by labels',
            'address group for search labels',
            'search => nameLabels',
            '',
            '1'
        ),
        (
            'host-4',
            'f0ab4c7f-f2a2-4aed-854c-1e6d70b145e1',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            '{fe80::1}',
            '(host-1, 1.0, linux, ubuntu, family, null)',
            'host 4',
            'for delete ns+name',
            'address group for delete',
            'delete => name',
            '',
            '1'
        ),
        (
            'host-5',
            '62c5eb08-40d4-4f94-a766-70101ff7541f',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            '{}',
            '(host-1, 1.0, linux, ubuntu, family, version)',
            'host 5',
            'for delete ns+name',
            'address group for delete',
            'delete => name',
            '',
            '1'
        ),
        (
            'host-6',
            '9fcce1ca-39ed-4ad0-8c1b-854497a1876f',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            '{}',
            '(host-1, 1.0, linux, ubuntu, family, version)',
            'host 6',
            'for hb',
            'host for hb',
            'host => hb',
            '',
            '1'
        ),
        (
            'host-7',
            'd1d04af8-d1a2-44f9-b15d-41d5ffef20db',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            '{}',
            '(host-1, 1.0, linux, ubuntu, family, version)',
            'host 7',
            'for hb',
            'host for hb',
            'host => hb',
            '',
            '1'
        );

    INSERT INTO sgroups.tbl_network(name, uid, ns, network, display_name, comment, description, labels, annotations, resource_version)
    VALUES
        (
            'nw-0',
            'bd1fca5a-9c08-4ecd-9673-61ec60e9b88b',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-0'),
            '1.1.1.1/32',
            'network 0',
            'for search by name/ns',
            'network for search',
            'labels => search',
            'search => labels',
            '1'
        ),
        (
            'nw-1',
            '987b4f77-0b5e-470e-85cf-037d79c37deb',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            '::1/128',
            'network 1',
            'for search by name/ns',
            'network for search',
            'labels => ns',
            'search => name',
            '1'
        ),
        (
            'nw-2',
            'de8bad6a-6989-41fc-8af1-9ebc4c123f8c',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-2'),
            '10.0.0.0/8',
            'network 2',
            'for search by labels',
            'network for search labels',
            'search => nameLabels',
            '',
            '1'
        ),
        (
            'nw-3',
            'a55e2af7-1fae-4c2e-8429-79be384c7039',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            '3.3.3.3/32',
            'network 3',
            'for search by labels',
            'network for search labels',
            'search => nameLabels',
            '',
            '1'
        ),
        (
            'nw-4',
            'cd94423b-fc15-4b5d-a029-05709f1af1fc',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            '7.7.7.7/32',
            'network 4',
            'for delete ns+name',
            'network for delete',
            'delete => name',
            '',
            '1'
        ),
        (
            'nw-5',
            '45fceac3-1314-4ac8-b8c2-0fa6fd56cbb7',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            '2.2.2.2/32',
            'network 5',
            'for delete ns+name',
            'network for delete',
            'network => name',
            '',
            '1'
        ),
        (
            'nw-6',
            '550e8400-e29b-41d4-a716-446655440000',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            '2.2.2.2/32',
            'network 6',
            'for nb',
            'network for nb',
            'network => nb',
            '',
            '1'
        ),
        (
            'nw-7',
            '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            '22.22.22.22/32',
            'network 7',
            'for nb',
            'network for nb',
            'network => nb',
            '',
            '1'
        );

    INSERT INTO sgroups.tbl_host_binding(name, uid, ns, ag, host, display_name, comment, description, labels, annotations, resource_version)
    VALUES
        (
            'hb-0',
            '1085d231-9a0f-4697-b864-c0a522181911',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-0'),
            (SELECT id FROM sgroups.tbl_ag WHERE name = 'ag-0'),
            (SELECT id FROM sgroups.tbl_host WHERE name = 'host-0'),
            'host binding 0',
            'for search by name/ns',
            'host binding for search',
            'labels => search',
            'search => labels',
            '1'
        ),
        (
            'hb-1',
            'af7ee13a-ed99-4d35-bf68-ba76bb5a446c',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            (SELECT id FROM sgroups.tbl_ag WHERE name = 'ag-1'),
            (SELECT id FROM sgroups.tbl_host WHERE name = 'host-1'),
            'host binding 1',
            'for search by name/ns',
            'host binding for search',
            'labels => ns',
            'search => name',
            '1'
        ),
        (
            'hb-2',
            '5bd57191-447f-4c72-a295-4e8fe5800f20',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-2'),
            (SELECT id FROM sgroups.tbl_ag WHERE name = 'ag-2'),
            (SELECT id FROM sgroups.tbl_host WHERE name = 'host-2'),
            'host binding 2',
            'for search by labels',
            'host binding for search labels',
            'search => nameLabels',
            '',
            '1'
        ),
        (
            'hb-3',
            'efb85252-c9b7-4dd5-b9be-6ce63276795c',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            (SELECT id FROM sgroups.tbl_ag WHERE name = 'ag-3'),
            (SELECT id FROM sgroups.tbl_host WHERE name = 'host-3'),
            'host binding 3',
            'for search by labels',
            'host binding for search labels',
            'search => nameLabels',
            '',
            '1'
        ),
        (
            'hb-4',
            'fa109b95-24ac-404a-9062-01ced3ab9541',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            (SELECT id FROM sgroups.tbl_ag WHERE name = 'ag-3'),
            (SELECT id FROM sgroups.tbl_host WHERE name = 'host-6'),
            'host binding 4',
            'for delete ns+name',
            'host binding for delete',
            'delete => name',
            '',
            '1'
        ),
        (
            'hb-5',
            '13155138-92ec-49e1-8a9e-2f1faac09dcd',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            (SELECT id FROM sgroups.tbl_ag WHERE name = 'ag-3'),
            (SELECT id FROM sgroups.tbl_host WHERE name = 'host-7'),
            'host binding 5',
            'for delete ns+name',
            'host binding for delete',
            'delete => name',
            '',
            '1'
        );

    INSERT INTO sgroups.tbl_network_binding(name, uid, ns, ag, network, display_name, comment, description, labels, annotations, resource_version)
    VALUES
        (
            'nb-0',
            '90ef841a-f480-405d-abb0-983baf038801',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-0'),
            (SELECT id FROM sgroups.tbl_ag WHERE name = 'ag-0'),
            (SELECT id FROM sgroups.tbl_network WHERE name = 'nw-0'),
            'network binding 0',
            'for search by name/ns',
            'network binding for search',
            'labels => search',
            'search => labels',
            '1'
        ),
        (
            'nb-1',
            '9b187907-29ef-4de1-a798-d6537c8a95b1',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            (SELECT id FROM sgroups.tbl_ag WHERE name = 'ag-1'),
            (SELECT id FROM sgroups.tbl_network WHERE name = 'nw-1'),
            'network binding 1',
            'for search by name/ns',
            'network binding for search',
            'labels => ns',
            'search => name',
            '1'
        ),
        (
            'nb-2',
            'fdcb56b7-94fe-412d-b7c7-e5ccf1f94085',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-2'),
            (SELECT id FROM sgroups.tbl_ag WHERE name = 'ag-2'),
            (SELECT id FROM sgroups.tbl_network WHERE name = 'nw-2'),
            'network binding 2',
            'for search by labels',
            'network binding for search labels',
            'search => nameLabels',
            '',
            '1'
        ),
        (
            'nb-3',
            '507404f0-6ddc-4d15-b7bd-6c59bdff1d24',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            (SELECT id FROM sgroups.tbl_ag WHERE name = 'ag-3'),
            (SELECT id FROM sgroups.tbl_network WHERE name = 'nw-3'),
            'network binding 3',
            'for search by labels',
            'network binding for search labels',
            'search => nameLabels',
            '',
            '1'
        ),
        (
            'nb-4',
            '7019ef05-b363-42a5-a070-4d205a9d729e',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            (SELECT id FROM sgroups.tbl_ag WHERE name = 'ag-3'),
            (SELECT id FROM sgroups.tbl_network WHERE name = 'nw-6'),
            'network binding 4',
            'for delete ns+name',
            'network binding for delete',
            'delete => name',
            '',
            '1'
        ),
        (
            'nb-5',
            'c3aae183-6261-471b-a024-7c435319cfdb',
            (SELECT id FROM sgroups.tbl_namespace WHERE name = 'namespace-1'),
            (SELECT id FROM sgroups.tbl_ag WHERE name = 'ag-3'),
            (SELECT id FROM sgroups.tbl_network WHERE name = 'nw-7'),
            'network binding 5',
            'for delete ns+name',
            'network binding for delete',
            'delete => name',
            '',
            '1'
        );
COMMIT;