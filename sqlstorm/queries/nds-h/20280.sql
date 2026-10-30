
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank_per_mfgr
    FROM 
        part p
), 
SupplierTotals AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), 
LatestOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS latest_order_rank
    FROM 
        orders o
), 
FilteredOrders AS (
    SELECT 
        lo.o_orderkey, 
        lo.o_orderdate, 
        lo.o_totalprice
    FROM 
        LatestOrders lo
    WHERE 
        lo.latest_order_rank = 1 AND lo.o_totalprice > 0 
), 
FinalResults AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        st.total_supply_cost,
        co.order_count,
        co.total_spent,
        COALESCE(NULLIF(co.total_spent, 0), 1) AS adjusted_total_spent
    FROM 
        RankedParts rp
    LEFT JOIN 
        SupplierTotals st ON rp.p_partkey = st.ps_partkey
    LEFT JOIN 
        CustomerOrders co ON co.c_custkey IS NOT NULL
    WHERE 
        rp.rank_per_mfgr <= 5 AND 
        (st.total_supply_cost IS NULL OR st.total_supply_cost < 1000) 
)
SELECT 
    fr.p_name,
    fr.p_retailprice,
    fr.total_supply_cost,
    fr.order_count,
    fr.total_spent,
    fr.adjusted_total_spent,
    CASE 
        WHEN fr.total_spent IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status,
    CASE 
        WHEN fr.p_retailprice IS NOT NULL AND fr.adjusted_total_spent IS NOT NULL THEN 
            fr.p_retailprice / fr.adjusted_total_spent 
        ELSE 
            NULL
    END AS price_to_spending_ratio
FROM 
    FinalResults fr
ORDER BY 
    fr.p_retailprice DESC, fr.total_spent ASC
LIMIT 50;
