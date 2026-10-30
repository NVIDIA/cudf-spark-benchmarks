
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders AS o
    WHERE 
        o.o_orderdate >= DATE '1994-01-01'
),
filtered_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        (CASE 
            WHEN p.p_size BETWEEN 1 AND 5 THEN 'Small'
            WHEN p.p_size BETWEEN 6 AND 15 THEN 'Medium'
            ELSE 'Large'
         END) AS size_category 
    FROM 
        part AS p
    WHERE 
        p.p_retailprice IS NOT NULL
),
total_quantity AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_qty
    FROM 
        lineitem AS l
    GROUP BY 
        l.l_orderkey
),
national_supplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        n.n_nationkey
    FROM 
        supplier AS s
    JOIN 
        nation AS n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name, n.n_nationkey
),
result_set AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT ns.n_nationkey) AS region_count,
        SUM(rating.total_qty) AS total_quantity
    FROM 
        region AS r
    LEFT JOIN 
        national_supplier AS ns ON ns.n_nationkey = r.r_regionkey
    LEFT JOIN 
        total_quantity AS rating ON ns.n_nationkey = rating.l_orderkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.region_count,
    COALESCE(SUM(fp.p_retailprice), 0.00) AS total_retail_price,
    AVG(ranking.o_totalprice) AS avg_order_price
FROM 
    result_set AS r
LEFT JOIN 
    filtered_parts AS fp ON r.region_count > 5
LEFT JOIN 
    ranked_orders AS ranking ON r.region_count = EXTRACT(YEAR FROM ranking.o_orderdate)
WHERE 
    r.region_count IS NOT NULL
GROUP BY 
    r.r_name, r.region_count
HAVING 
    AVG(ranking.o_totalprice) > (SELECT AVG(o.o_totalprice) FROM orders AS o)
ORDER BY 
    r.r_name DESC 
LIMIT 
    10 OFFSET 5;
