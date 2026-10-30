WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) as price_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp WHERE ps_partkey = p.p_partkey)
),
top_parts AS (
    SELECT 
        r.r_name,
        n.n_name,
        s.s_name,
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        rp.ps_supplycost
    FROM 
        ranked_parts rp
    LEFT JOIN 
        supplier s ON rp.p_partkey = s.s_suppkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rp.price_rank <= 3 AND 
        r.r_name IS NOT NULL
),
final_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_order_price,
        COUNT(DISTINCT li.l_linenumber) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND li.l_returnflag = 'N'
        AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    tp.r_name AS region_name,
    tp.n_name AS nation_name,
    tp.s_name AS supplier_name,
    fo.o_orderkey,
    fo.total_order_price,
    CASE 
        WHEN fo.line_count > 5 THEN 'Large Order'
        ELSE 'Regular Order'
    END AS order_type
FROM 
    top_parts tp
JOIN 
    final_orders fo ON tp.p_partkey IN (
        SELECT DISTINCT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = fo.o_orderkey
    )
WHERE 
    tp.ps_supplycost < (
        SELECT AVG(ps_supplycost) 
        FROM partsupp 
        WHERE ps_partkey = tp.p_partkey
    ) OR 
    tp.ps_supplycost IS NULL
ORDER BY 
    tp.r_name, fo.total_order_price DESC;