
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        s.s_suppkey AS ps_partkey -- Assuming `s.s_suppkey` is to match with `p.p_partkey`
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_container,
    p.p_retailprice,
    COALESCE(s.total_available_qty, 0) AS total_available_qty,
    COALESCE(s.avg_supply_cost, 0) AS avg_supply_cost,
    cs.total_spent,
    cs.order_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS product_rank
FROM 
    part p
LEFT JOIN 
    SupplierStats s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    CustomerOrderSummary cs ON cs.total_spent > p.p_retailprice
WHERE 
    (p.p_size > 10 OR p.p_comment LIKE '%special%')
    AND p.p_retailprice BETWEEN 10 AND 100
    AND EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey 
        AND l.l_returnflag = 'N'
    )
ORDER BY 
    p.p_brand, total_spent DESC;
