WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
SuppliersWithParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(NULLIF(SUBSTRING(p.p_comment, 1, 10), ''), 'N/A') AS brief_comment,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey AND l.l_shipdate >= '1997-06-01'
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice, p.p_comment
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 5000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    p.p_name,
    p.brief_comment,
    s.s_name AS supplier_name,
    CASE 
        WHEN s.part_count IS NULL THEN 'No parts associated' 
        ELSE CONCAT('Parts Count: ', s.part_count) 
    END AS part_info,
    c.total_spent,
    ROW_NUMBER() OVER (PARTITION BY r.o_orderkey ORDER BY r.o_totalprice DESC) AS order_rank
FROM RankedOrders r
LEFT JOIN PartDetails p ON r.o_orderkey = p.p_partkey
LEFT JOIN SuppliersWithParts s ON p.p_partkey = s.part_count
LEFT JOIN HighValueCustomers c ON r.o_orderkey = c.c_custkey
WHERE 
    (p.total_returned > 0 OR p.p_retailprice > 100)
    AND (c.total_spent IS NULL OR c.total_spent < 10000)
ORDER BY r.o_orderdate DESC, r.o_totalprice ASC
LIMIT 20;