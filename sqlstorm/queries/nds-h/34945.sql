WITH  RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
SalesData AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, c.c_nationkey
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        SUM(sd.total_sales) AS total_nation_sales
    FROM 
        SalesData sd
    JOIN 
        nation n ON sd.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    ns.total_nation_sales,
    ss.part_count,
    ss.avg_acctbal,
    COALESCE(rp.ps_supplycost, 0) AS supply_cost,
    CASE
        WHEN ns.total_nation_sales > 100000 THEN 'High Sales'
        WHEN ns.total_nation_sales BETWEEN 50000 AND 100000 THEN 'Moderate Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    RankedParts rp
FULL OUTER JOIN 
    SupplierStats ss ON rp.p_partkey = ss.part_count
LEFT JOIN 
    NationSales ns ON ss.part_count = ns.total_nation_sales
WHERE 
    rp.rank <= 5 OR ss.part_count IS NULL
ORDER BY 
    ns.total_nation_sales DESC, rp.p_brand;