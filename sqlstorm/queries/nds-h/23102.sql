
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ps.ps_availqty,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice IS NOT NULL AND 
        ps.ps_availqty > 0
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey
), NationSupply AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(COALESCE(ps.ps_supplycost, 0)) AS total_supply_cost
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
), FinalAggregation AS (
    SELECT 
        cp.c_custkey,
        cp.order_count,
        cp.total_spent,
        rp.p_partkey,
        rp.p_name, 
        rp.p_retailprice,
        ns.total_supply_cost
    FROM 
        CustomerOrders cp
    JOIN 
        RankedParts rp ON cp.order_count > 5
    LEFT JOIN 
        NationSupply ns ON ns.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
    WHERE 
        rp.price_rank <= 10
)
SELECT 
    fa.c_custkey,
    fa.order_count,
    fa.total_spent,
    fa.p_partkey,
    fa.p_name,
    fa.p_retailprice,
    COALESCE(fa.total_supply_cost, 0) AS net_supply_cost,
    CASE 
        WHEN fa.p_retailprice > 1000 THEN 'Expensive' 
        ELSE 'Affordable' 
    END AS price_category,
    CASE 
        WHEN fa.order_count > 10 AND fa.total_spent > 5000 THEN 'VIP' 
        ELSE 'Regular' 
    END AS customer_status
FROM 
    FinalAggregation fa
ORDER BY 
    fa.total_spent DESC, fa.p_retailprice ASC
LIMIT 50;
