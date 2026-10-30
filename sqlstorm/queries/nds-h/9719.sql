
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        ps.ps_supplycost,
        ps.ps_availqty,
        RANK() OVER (PARTITION BY p.p_type ORDER BY ps.ps_supplycost ASC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
TopBudgetCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 5000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        tc.c_custkey
    FROM 
        RecentOrders ro
    JOIN 
        TopBudgetCustomers tc ON ro.o_custkey = tc.c_custkey
    WHERE 
        ro.o_totalprice > 10000
)
SELECT 
    r.p_name,
    r.p_brand,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_sales,
    MAX(o.o_orderdate) AS last_order_date
FROM 
    RankedParts r
JOIN 
    lineitem l ON r.p_partkey = l.l_partkey
JOIN 
    HighValueOrders o ON l.l_orderkey = o.o_orderkey
WHERE 
    r.rank = 1
GROUP BY 
    r.p_name, r.p_brand
ORDER BY 
    total_sales DESC
LIMIT 10;
