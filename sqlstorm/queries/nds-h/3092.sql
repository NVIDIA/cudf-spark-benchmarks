
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '3 months'
),
SupplierPartCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(SPC.total_supplycost, 0) AS total_supplycost,
    COALESCE(SPC.total_availqty, 0) AS total_availqty,
    COALESCE(CO.avg_order_value, 0) AS avg_order_value,
    RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
FROM 
    part p
LEFT JOIN 
    SupplierPartCosts SPC ON p.p_partkey = SPC.ps_partkey
LEFT JOIN 
    CustomerOrders CO ON CO.c_custkey IS NOT NULL AND CO.order_count > 5
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice)
        FROM part p2
        WHERE p2.p_type LIKE '%metal%'
    )
AND 
    EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_partkey = p.p_partkey
        AND l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    )
ORDER BY 
    price_rank, p.p_name;
