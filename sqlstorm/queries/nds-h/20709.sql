WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
), 
NationSupplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
), 
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
        MAX(l.l_shipdate) AS latest_ship_date
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT ps.ps_suppkey) AS distinct_suppliers,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    SUM(CASE WHEN lp.price_rank = 1 THEN lp.p_retailprice ELSE 0 END) AS top_brand_price_sum,
    COALESCE(SUM(ls.net_value), 0) AS total_net_value,
    (SELECT 
        AVG(test_value) 
     FROM (
        SELECT 
            COUNT(DISTINCT o.o_orderkey) AS test_value
        FROM 
            orders o
        JOIN 
            customer c ON o.o_custkey = c.c_custkey
        WHERE 
            c.c_acctbal > 0
        GROUP BY 
            c.c_nationkey
     ) AS subquery) AS avg_orders_per_nation
FROM 
    NationSupplier ns 
LEFT JOIN 
    partsupp ps ON ns.n_nationkey = ps.ps_suppkey
LEFT JOIN 
    RankedParts lp ON ps.ps_partkey = lp.p_partkey AND lp.price_rank <= 3
LEFT JOIN 
    LineItemSummary ls ON ls.l_orderkey = ps.ps_partkey
GROUP BY 
    ns.n_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 1
    AND SUM(ps.ps_availqty) > 1000
ORDER BY 
    total_net_value DESC;
