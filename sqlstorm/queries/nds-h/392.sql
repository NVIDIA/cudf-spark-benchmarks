
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND
        o.o_orderdate < DATE '1998-01-01'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerInfo AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        n.n_name AS nation_name,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > 0
)
SELECT 
    c.c_name,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS num_orders,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    AVG(CASE WHEN c.c_acctbal > 1000 THEN l.l_discount ELSE NULL END) AS avg_discount_high_value_customers,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY COUNT(DISTINCT o.o_orderkey) DESC) AS region_rank
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    CustomerInfo c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.nation_name = n.n_name
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierCosts sc ON sc.ps_partkey = l.l_partkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND 
    l.l_shipdate <= DATE '1997-12-31'
GROUP BY 
    c.c_name, r.r_name, r.r_regionkey
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC, region_rank;
