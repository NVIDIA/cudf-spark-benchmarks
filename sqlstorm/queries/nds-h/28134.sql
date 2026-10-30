WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
filtered_nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        n.n_comment LIKE '%leader%'
),
customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    p.p_brand,
    n.n_name AS nation_name,
    co.total_orders,
    CASE 
        WHEN co.total_orders > 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS customer_type
FROM 
    ranked_parts p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    filtered_nations n ON s.s_nationkey = n.n_nationkey
JOIN 
    customer_orders co ON s.s_nationkey = co.c_custkey
WHERE 
    p.brand_rank <= 5
ORDER BY 
    p.p_retailprice DESC, co.total_orders DESC
LIMIT 100;
