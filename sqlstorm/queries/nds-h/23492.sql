WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= (cast('1998-10-01' as date) - INTERVAL '1 year')
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    WHERE
        ps.ps_availqty > 0
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
FilteredProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        (SELECT COUNT(DISTINCT c.c_custkey) 
         FROM customer c 
         WHERE c.c_nationkey = n.n_nationkey) AS cust_count
    FROM 
        part p
    JOIN 
        supplier s ON p.p_partkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_retailprice BETWEEN 10.00 AND 100.00
        AND n.n_name NOT LIKE '%A%'
        AND s.s_acctbal IS NOT NULL
)
SELECT 
    rp.o_orderkey,
    fp.p_name,
    fp.p_retailprice,
    CASE 
        WHEN sa.total_availqty IS NULL THEN 'Unavailable'
        ELSE 'Available'
    END AS availability,
    COALESCE(rp.o_totalprice, 0) AS order_total_price,
    fp.cust_count
FROM 
    RankedOrders rp
LEFT JOIN 
    FilteredProducts fp ON rp.o_orderkey = fp.p_partkey
LEFT JOIN 
    SupplierAvailability sa ON fp.p_partkey = sa.ps_partkey
WHERE 
    rp.order_rank = 1 
    OR (fp.p_name IS NOT NULL AND fp.p_brand IS NOT NULL)
ORDER BY 
    availability DESC, 
    order_total_price DESC
LIMIT 50;