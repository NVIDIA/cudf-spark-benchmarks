
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopPurchasers AS (
    SELECT 
        cp.c_custkey,
        cp.c_name,
        cp.total_spent,
        cp.order_count,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS spender_rank
    FROM 
        CustomerPurchases cp
    WHERE 
        cp.total_spent > (SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_spent) FROM CustomerPurchases)
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    tp.c_name AS top_customer,
    tp.total_spent AS customer_spending,
    tp.order_count AS order_count,
    rp.p_comment
FROM 
    RankedParts rp
JOIN 
    TopPurchasers tp ON rp.p_brand = tp.c_name
WHERE 
    rp.price_rank <= 5
ORDER BY 
    rp.p_retailprice DESC, tp.total_spent DESC;
