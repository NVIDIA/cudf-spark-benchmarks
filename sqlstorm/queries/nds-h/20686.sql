WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
AvailableParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty,
        COALESCE(ps.ps_supplycost * ps.ps_availqty, 0) AS total_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size BETWEEN 1 AND 10 
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND 
        c.c_name LIKE '%Inc%'
    GROUP BY 
        c.c_custkey, c.c_name
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        c.c_custkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < cast('1998-10-01' as date))
),
FinalSelection AS (
    SELECT 
        a.p_partkey, 
        a.p_name, 
        a.ps_availqty, 
        a.total_cost, 
        c.total_spent, 
        COALESCE(s.rn, 0) AS rank
    FROM 
        AvailableParts a
    INNER JOIN 
        CustomerOrderSummary c ON a.p_partkey % 10 = c.c_custkey % 10 
    LEFT JOIN 
        RankedSuppliers s ON c.c_custkey = s.s_suppkey
)
SELECT 
    f.p_partkey, 
    f.p_name, 
    f.ps_availqty, 
    f.total_cost, 
    f.total_spent, 
    f.rank
FROM 
    FinalSelection f
ORDER BY 
    CASE WHEN f.rank IS NULL THEN 1 ELSE 0 END, 
    f.total_cost DESC, 
    f.total_spent ASC
LIMIT 100;