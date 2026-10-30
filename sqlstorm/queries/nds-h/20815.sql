
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
        p.p_retailprice,
        COALESCE(NULLIF(p.p_container, 'NONE'), 'UNKNOWN') AS effective_container
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 10
),
SuppliersAvailability AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        CTE.customer_count,
        CASE 
            WHEN COUNT(l.l_orderkey) > 5 THEN 'High Volume'
            ELSE 'Low Volume'
        END AS order_volume
    FROM 
        orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN (
        SELECT 
            o.o_custkey,
            COUNT(DISTINCT o.o_orderkey) AS customer_count
        FROM 
            orders o
        GROUP BY 
            o.o_custkey
        HAVING 
            COUNT(DISTINCT o.o_orderkey) > 1
    ) CTE ON o.o_custkey = CTE.o_custkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, CTE.customer_count
)
SELECT 
    n.n_name AS nation_name,
    SUM(RP.p_retailprice) AS total_retail_price,
    AVG(SA.average_supply_cost) AS avg_supply_cost,
    MAX(CO.order_volume) AS max_order_volume
FROM 
    RankedParts RP
JOIN 
    partsupp PS ON RP.p_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    nation n ON S.s_nationkey = n.n_nationkey
LEFT JOIN 
    SuppliersAvailability SA ON S.s_suppkey = SA.ps_suppkey
LEFT JOIN 
    CustomerOrders CO ON S.s_nationkey = n.n_nationkey
WHERE 
    EXISTS (
        SELECT 1 FROM lineitem L 
        WHERE L.l_suppkey = S.s_suppkey 
        AND L.l_discount > 0.1
    )
    AND (RP.price_rank = 1 OR RP.effective_container <> 'UNKNOWN')
GROUP BY 
    n.n_name
HAVING 
    SUM(RP.p_retailprice) IS NOT NULL 
    AND COUNT(DISTINCT CO.o_orderkey) > 2
ORDER BY 
    max_order_volume DESC, total_retail_price DESC;
