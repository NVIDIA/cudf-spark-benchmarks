
WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
OrdersWithHighValues AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        d.r_name AS delivery_region,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region d ON n.n_regionkey = d.r_regionkey
    WHERE 
        o.o_orderstatus = 'F'
        AND EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_partkey = l.l_partkey AND ps.ps_availqty < 100)
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, d.r_name
    HAVING 
        COUNT(DISTINCT l.l_partkey) > 5
),
FinalReport AS (
    SELECT 
        oh.o_orderkey,
        oh.o_totalprice,
        oh.o_orderdate,
        oh.item_count,
        COALESCE(rn.s_name, 'Unknown Supplier') AS supplier_name,
        hp.p_name AS high_value_part
    FROM 
        OrdersWithHighValues oh
    LEFT JOIN 
        RankedSupplier rn ON rn.rnk = 1
    LEFT JOIN 
        HighValueParts hp ON hp.price_rank <= 10
    ORDER BY 
        oh.o_orderdate DESC, oh.o_totalprice DESC
)
SELECT 
    DISTINCT fr.o_orderkey,
    fr.o_orderdate,
    fr.item_count,
    fr.supplier_name,
    fr.high_value_part
FROM 
    FinalReport fr
WHERE 
    fr.high_value_part IS NOT NULL
    AND fr.o_orderdate >= CURRENT_DATE - INTERVAL '3 months'
    AND fr.item_count BETWEEN (SELECT AVG(item_count) FROM FinalReport) AND (SELECT MAX(item_count) FROM FinalReport)
ORDER BY 
    fr.o_orderdate DESC;
