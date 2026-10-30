WITH RankedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_linenumber,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_discount DESC, l.l_extendedprice ASC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1996-01-01' AND '1997-12-31'
),
BestDiscounts AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_profit
    FROM RankedLineItems l
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE l.rn = 1
    GROUP BY CUBE (r.r_name, n.n_name, s.s_name)
),
NullHandles AS (
    SELECT 
        COALESCE(b.region_name, 'Unknown Region') AS region_name,
        COALESCE(b.nation_name, 'Unknown Nation') AS nation_name,
        COALESCE(b.supplier_name, 'Unknown Supplier') AS supplier_name,
        SUM(CASE WHEN b.net_profit IS NULL THEN 0 ELSE b.net_profit END) AS total_net_profit
    FROM BestDiscounts b
    GROUP BY ROLLUP (b.region_name, b.nation_name, b.supplier_name)
)

SELECT 
    n.region_name,
    n.nation_name,
    n.supplier_name,
    n.total_net_profit,
    CASE 
        WHEN n.total_net_profit IS NULL THEN 'No Profit'
        WHEN n.total_net_profit > 10000 THEN 'High Profit'
        WHEN n.total_net_profit BETWEEN 5000 AND 10000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM NullHandles n
ORDER BY n.total_net_profit DESC NULLS LAST;