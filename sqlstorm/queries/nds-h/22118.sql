
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
SupplierQualification AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown' 
            WHEN s.s_acctbal < 0 THEN 'Negative Balance' 
            ELSE 'Valid Account' 
        END AS acct_status
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL OR s.s_acctbal < 0
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_price
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > 5
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 0
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
),
FinalReport AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        COALESCE(SUM(ps.total_avail_qty), 0) AS total_available_quantity,
        COALESCE(AVG(ps.average_supply_cost), 0) AS avg_supply_cost,
        cs.order_count,
        cs.max_order_price
    FROM 
        RankedParts rp
    LEFT JOIN 
        PartSupplier ps ON rp.p_partkey = ps.ps_partkey
    LEFT JOIN 
        CustomerStats cs ON ps.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE'))
    WHERE 
        rp.price_rank <= 10
    GROUP BY 
        rp.p_partkey, rp.p_name, rp.p_brand, cs.order_count, cs.max_order_price
)
SELECT 
    f.p_name,
    f.p_brand,
    f.total_available_quantity,
    f.avg_supply_cost,
    f.order_count,
    f.max_order_price
FROM 
    FinalReport f
WHERE 
    f.total_available_quantity > 0 
    AND f.avg_supply_cost IS NOT NULL 
    AND (f.order_count IS NULL OR f.order_count > 0)
ORDER BY 
    f.p_brand, f.total_available_quantity DESC, f.max_order_price ASC
LIMIT 100;
