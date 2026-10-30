
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SuppliedParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 100
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
DiscountedLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_discount,
        l.l_extendedprice,
        (l.l_extendedprice * (1 - l.l_discount)) AS discounted_price
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.10
),
FinalSummary AS (
    SELECT 
        r.r_name,
        SUM(cl.total_spent) AS total_customer_spent,
        COUNT(DISTINCT cl.c_custkey) AS unique_customers,
        AVG(dp.discounted_price) AS avg_discounted_price
    FROM 
        CustomerOrders cl
    JOIN 
        nation n ON cl.c_custkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        DiscountedLineItems dp ON dp.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cl.c_custkey)
    GROUP BY 
        r.r_name
)
SELECT 
    fs.r_name,
    fs.total_customer_spent,
    fs.unique_customers,
    COALESCE(fs.avg_discounted_price, 0) AS avg_discounted_price,
    (SELECT COUNT(*) FROM RankedParts rp WHERE rp.rank <= 5) AS top_part_count
FROM 
    FinalSummary fs
ORDER BY 
    fs.total_customer_spent DESC
LIMIT 10;
