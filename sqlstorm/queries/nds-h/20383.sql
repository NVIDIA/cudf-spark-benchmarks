WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
), HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, 
        p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 5000
), LatestOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
), CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.n_name AS nation_name, 
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns,
    CASE 
        WHEN EXISTS (SELECT 1 FROM RankedSuppliers rs WHERE rs.rank = 1) 
        THEN (SELECT MAX(total_supply_value) FROM HighValueParts) 
        ELSE NULL 
    END AS max_high_value_part_supply,
    COALESCE(AVG(cs.avg_order_value), 0) AS average_customer_order_value
FROM 
    nation r
JOIN 
    customer c ON c.c_nationkey = r.n_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    CustomerStats cs ON c.c_custkey = cs.c_custkey
GROUP BY 
    r.n_name
HAVING 
    MAX(o.o_orderdate) < cast('1998-10-01' as date) - INTERVAL '1 year'
ORDER BY 
    customer_count DESC
LIMIT 10;