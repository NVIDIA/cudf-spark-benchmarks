
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01'
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sp.total_suppliers, 0) AS total_suppliers,
    COALESCE(sp.total_supply_value, 0.00) AS total_supply_value,
    COUNT(DISTINCT lo.l_orderkey) AS total_orders,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    CASE 
        WHEN AVG(lo.l_tax) IS NULL THEN 'No Tax Data'
        ELSE CONCAT('Avg Tax: ', CAST(AVG(lo.l_tax) AS VARCHAR(255)))
    END AS average_tax_info
FROM 
    part p
LEFT JOIN 
    lineitem lo ON p.p_partkey = lo.l_partkey
LEFT JOIN 
    SupplierPartStats sp ON p.p_partkey = sp.ps_partkey
GROUP BY 
    p.p_partkey, p.p_name, sp.total_suppliers, sp.total_supply_value
HAVING 
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 1000.00
    OR COUNT(DISTINCT lo.l_orderkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 10;
