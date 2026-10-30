
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '12 MONTH'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT *
    FROM CustomerPurchases
    WHERE total_spent > (
        SELECT AVG(total_spent) FROM CustomerPurchases
    )
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nations_count,
    SUM(ss.total_available) AS total_supply,
    AVG(ss.avg_supply_cost) AS avg_supplier_cost,
    SUM(hvc.total_spent) AS aggregate_spendings
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = ss.s_suppkey
LEFT JOIN 
    HighValueCustomers hvc ON n.n_nationkey = hvc.c_custkey
GROUP BY 
    r.r_name
HAVING 
    SUM(ss.total_available) > 1000
ORDER BY 
    aggregate_spendings DESC NULLS LAST;
