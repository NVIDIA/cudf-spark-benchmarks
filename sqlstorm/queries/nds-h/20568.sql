WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate > (cast('1998-10-01' as date) - INTERVAL '2 years')
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 100000
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_container,
        COALESCE(NULLIF(p.p_comment, ''), 'No comment') AS safe_comment
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 50)
),
CustomerOrders AS (
    SELECT 
        co.custkey,
        co.name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        (SELECT 
            c.c_custkey AS custkey,
            c.c_name AS name
        FROM 
            customer c
        WHERE 
            c.c_acctbal IS NOT NULL AND c.c_mktsegment NOT IN ('AUTOMOBILE', 'FURNITURE')) co
        LEFT JOIN orders o ON co.custkey = o.o_custkey
    GROUP BY 
        co.custkey, co.name
)
SELECT 
    r.o_orderkey,
    h.c_name,
    p.p_name,
    s.total_supplycost,
    RANK() OVER (PARTITION BY h.c_name ORDER BY r.o_orderdate DESC) AS order_rank,
    CASE 
        WHEN s.num_parts IS NULL THEN 'No parts supplied'
        ELSE CONCAT('Supplied ', s.num_parts, ' parts')
    END AS supply_info,
    CASE 
        WHEN p.p_retailprice > 0 THEN p.p_retailprice * (1 - COALESCE(NULLIF(l.l_discount, 0), 0))
        ELSE 0
    END AS final_price
FROM 
    RankedOrders r
    JOIN HighValueCustomers h ON r.o_custkey = h.c_custkey 
    LEFT JOIN lineitem l ON r.o_orderkey = l.l_orderkey
    LEFT JOIN PartDetails p ON l.l_partkey = p.p_partkey
    JOIN SupplierStats s ON l.l_suppkey = s.s_suppkey
WHERE 
    r.rn = 1
    AND p.p_name LIKE '%special%'
ORDER BY 
    h.total_spent DESC, r.o_orderdate ASC;