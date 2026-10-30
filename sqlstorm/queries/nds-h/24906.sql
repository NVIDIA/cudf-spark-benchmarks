
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-12-31'
), 

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(s.s_acctbal) AS average_balance,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 

HighValueSuppliers AS (
    SELECT 
        s.s_name,
        s.total_supply_value,
        s.average_balance
    FROM 
        SupplierDetails s
    WHERE 
        s.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierDetails)
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_tax) AS max_tax_rate,
    COALESCE(SUM(hv.total_supply_value), 0) AS high_value_supply_contribution
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    HighValueSuppliers hv ON hv.s_name = s.s_name
WHERE 
    n.n_name IS NOT NULL 
    AND (o.o_orderstatus IS NULL OR o.o_orderstatus <> 'F') 
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-06-30'
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
    OR MAX(l.l_tax) IS NULL
ORDER BY 
    total_orders DESC, high_value_supply_contribution DESC;
