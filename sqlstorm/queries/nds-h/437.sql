WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderdate < '1997-12-31'
), 

SupplierPartCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    COALESCE(spc.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN spc.supplier_count IS NULL THEN 'No Suppliers'
        ELSE CONCAT('Suppliers Count: ', spc.supplier_count)
    END AS supplier_status,
    AVG(RO.order_rank) OVER (PARTITION BY p.p_brand) AS avg_order_rank_per_brand
FROM 
    part p 
LEFT JOIN 
    SupplierPartCost spc ON p.p_partkey = spc.ps_partkey
LEFT JOIN 
    RankedOrders RO ON p.p_partkey = RO.o_orderkey
WHERE 
    p.p_size BETWEEN 1 AND 20 
    AND p.p_retailprice > (
        SELECT AVG(p2.p_retailprice)
        FROM part p2
        WHERE p2.p_size > 10
    )
ORDER BY 
    total_supply_cost DESC, 
    avg_order_rank_per_brand DESC;