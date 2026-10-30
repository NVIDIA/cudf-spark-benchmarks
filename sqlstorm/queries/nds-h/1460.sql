WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(s.total_cost, 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        SupplierCosts s ON p.p_partkey = s.ps_partkey
),
TopParts AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.p_brand,
        pd.p_retailprice,
        pd.total_supply_cost,
        (pd.p_retailprice - pd.total_supply_cost) AS profit_margin
    FROM 
        PartDetails pd
    WHERE 
        pd.total_supply_cost > 0 AND (pd.p_retailprice - pd.total_supply_cost) > 100
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    AVG(lo.l_quantity) AS avg_quantity,
    MAX(lp.profit_margin) AS max_profit_margin,
    MIN(lp.profit_margin) AS min_profit_margin
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    lineitem lo ON s.s_suppkey = lo.l_suppkey
JOIN 
    orders o ON lo.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    TopParts lp ON lo.l_partkey = lp.p_partkey
WHERE 
    o.o_orderstatus IN ('O', 'F')
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5 AND SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;