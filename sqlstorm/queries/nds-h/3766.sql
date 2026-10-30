WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01'
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS unique_nations,
    SUM(COALESCE(sa.total_available, 0)) AS total_stock,
    AVG(cp.total_spent) AS avg_spent_per_customer,
    MAX(o.o_totalprice) AS max_order_value
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierAvailability sa ON sa.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'BrandX')
LEFT JOIN 
    CustomerPurchases cp ON cp.c_custkey IS NOT NULL
LEFT JOIN 
    RankedOrders o ON o.o_orderkey IN (SELECT o2.o_orderkey FROM orders o2 WHERE o2.o_orderstatus = 'O')
WHERE 
    r.r_comment LIKE '%important%'
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY 
    total_stock DESC, avg_spent_per_customer ASC;