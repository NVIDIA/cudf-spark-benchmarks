
WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        s.s_name AS supplier_name,
        n.n_name AS nation_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
), 
RegionAnalysis AS (
    SELECT 
        r.r_name AS region,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(co.total_spent) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY 
        r.r_name
)
SELECT 
    rd.region,
    rd.customer_count,
    rd.total_sales,
    pd.p_name,
    pd.p_brand,
    pd.p_retailprice,
    ROW_NUMBER() OVER (PARTITION BY rd.region ORDER BY rd.total_sales DESC) AS sales_rank
FROM 
    RegionAnalysis rd
JOIN 
    PartDetails pd ON pd.p_partkey IN (
        SELECT DISTINCT ps.ps_partkey 
        FROM supplier s 
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
        WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n)
        AND ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type LIKE 'METAL%')
    )
ORDER BY 
    rd.region, sales_rank;
