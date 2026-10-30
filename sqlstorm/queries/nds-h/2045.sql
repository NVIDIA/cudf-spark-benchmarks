WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 10000
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '90 DAY'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        COUNT(l.l_orderkey) > 5
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(rn, 0) AS supplier_rank,
    COALESCE(tc.total_order_value, 0) AS high_value_customer
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    HighValueCustomers tc ON l.l_orderkey = tc.c_custkey
WHERE 
    p.p_retailprice > 50.00 
    AND l.l_shipdate IS NOT NULL
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, rn, tc.total_order_value
ORDER BY 
    total_revenue DESC
LIMIT 100;