WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS revenue,
    COALESCE(SC.total_supply_cost, 0) AS supplier_cost,
    R.order_rank
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    SupplierCosts SC ON p.p_partkey = SC.ps_partkey
LEFT JOIN 
    RankedOrders R ON R.o_orderkey = l.l_orderkey
WHERE 
    (l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' OR l.l_shipdate IS NULL)
    AND p.p_size > 10 
    AND p.p_retailprice IS NOT NULL
GROUP BY 
    p.p_partkey, p.p_name, SC.total_supply_cost, R.order_rank
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    revenue DESC, supplier_cost ASC;