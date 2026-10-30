
WITH ranked_prices AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
supplier_aggregate AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
customer_orders AS (
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
),
filtered_nations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    INNER JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_comment LIKE '%important%'
)
SELECT 
    c.c_custkey, 
    c.c_name,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    np.n_name AS nation_name,
    CASE 
        WHEN co.order_count > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type
FROM 
    customer_orders co
JOIN 
    customer c ON co.c_custkey = c.c_custkey
LEFT JOIN 
    supplier_aggregate s ON s.ps_suppkey = (
        SELECT ps_suppkey 
        FROM partsupp 
        WHERE ps_partkey IN (
            SELECT p.p_partkey 
            FROM ranked_prices p
            WHERE p.price_rank = 1
        ) 
        ORDER BY ps_supplycost DESC 
        LIMIT 1
    )
LEFT JOIN 
    filtered_nations np ON c.c_nationkey = np.n_nationkey
WHERE 
    (np.region_name IS NOT NULL OR co.max_order_price > 500.00)
ORDER BY 
    c.c_custkey DESC 
LIMIT 100;
