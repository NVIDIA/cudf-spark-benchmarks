
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierPricing AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        ps.ps_supplycost,
        p.p_retailprice,
        (p.p_retailprice - ps.ps_supplycost) AS price_difference
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(cs.total_spent) AS avg_customer_spending,
    SP.price_difference AS supplier_price_difference
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierPricing SP ON s.s_suppkey = SP.ps_suppkey
JOIN 
    lineitem lp ON SP.ps_partkey = lp.l_partkey
JOIN 
    RankedOrders o ON lp.l_orderkey = o.o_orderkey
JOIN 
    CustomerStats cs ON cs.total_orders > 0
WHERE 
    r.r_name LIKE '%West%'
GROUP BY 
    r.r_name, n.n_name, SP.price_difference
HAVING 
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) > 1000000 
ORDER BY 
    total_revenue DESC;
