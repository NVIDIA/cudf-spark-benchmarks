
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rk
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighSpenders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
FilteredGoods AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(ps.ps_availqty, 0) AS available_quantity,
        COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS returns_quantity
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey 
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, ps.ps_availqty
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > 0
)
SELECT 
    fg.p_partkey,
    fg.p_name,
    fg.p_brand,
    fg.p_retailprice,
    fg.available_quantity,
    fg.returns_quantity,
    sr.nation_name,
    sr.region_name,
    hs.total_spent
FROM 
    FilteredGoods fg
FULL OUTER JOIN 
    SupplierRegion sr ON fg.p_partkey = (SELECT MIN(ps_partkey) FROM partsupp WHERE ps_availqty > 0)
LEFT JOIN 
    HighSpenders hs ON sr.s_suppkey = hs.c_custkey
WHERE 
    fg.p_retailprice BETWEEN 100 AND 500
    AND fg.returns_quantity > 0
ORDER BY 
    sr.region_name DESC, 
    fg.p_partkey ASC
LIMIT 100;
