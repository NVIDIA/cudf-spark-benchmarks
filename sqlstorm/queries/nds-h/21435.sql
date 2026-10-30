WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        o.o_orderstatus
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    p.p_name,
    COALESCE(sd.s_name, 'No Supplier') AS supplier_name,
    os.lineitem_count,
    os.total_price_after_discount,
    RANK() OVER (PARTITION BY sd.s_nationkey ORDER BY os.total_price_after_discount DESC) AS nation_rank,
    CASE
        WHEN os.o_orderstatus = 'F' THEN 'Finalized'
        ELSE 'Pending'
    END AS order_status_flag
FROM 
    RankedParts p
LEFT JOIN 
    SupplierDetails sd ON p.p_partkey = sd.s_suppkey
LEFT JOIN 
    OrderSummary os ON sd.s_suppkey = os.o_orderkey
WHERE 
    p.price_rank = 1
    AND (sd.total_supply_cost IS NULL OR sd.total_supply_cost > 50000)
    AND (os.total_price_after_discount IS NOT NULL AND os.total_price_after_discount < 100000)
ORDER BY 
    nation_rank, p.p_name;
