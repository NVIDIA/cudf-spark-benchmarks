WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
), 
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) as total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) as customer_rank
    FROM 
        customer_orders c
)
SELECT 
    tp.c_name AS top_customer_name,
    rp.p_name AS popular_part_name,
    rp.p_brand AS popular_part_brand,
    rp.p_retailprice AS popular_part_price
FROM 
    top_customers tp
JOIN 
    ranked_parts rp ON tp.customer_rank <= 10 AND rp.rank = 1
WHERE 
    rp.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    tp.total_spent DESC, rp.p_retailprice ASC;
