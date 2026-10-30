WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size > 5
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStatistics AS (
    SELECT 
        o.o_clerk,
        AVG(o.o_totalprice) AS avg_order_price,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        orders o
    GROUP BY 
        o.o_clerk
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    sd.s_name,
    sd.part_count,
    os.o_clerk,
    os.avg_order_price,
    os.total_orders
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    OrderStatistics os ON os.o_clerk = 'CLERK_1'
WHERE 
    rp.price_rank <= 5
ORDER BY 
    rp.p_retailprice DESC, sd.total_supply_cost DESC;
