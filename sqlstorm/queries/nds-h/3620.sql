WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    WHERE 
        li.l_shipdate >= DATE '1997-01-01' 
        AND li.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_mfgr
),
TopSales AS (
    SELECT 
        ts.p_partkey,
        ts.p_name,
        ts.p_brand,
        ts.total_sales,
        CASE 
            WHEN ts.rank <= 10 THEN 'Top 10'
            ELSE 'Others'
        END AS sales_category
    FROM 
        RankedSales ts
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    ts.sales_category,
    ts.p_brand,
    ts.p_name,
    ts.total_sales,
    COALESCE(sd.total_supply_value, 0) AS supplier_total_value,
    r.r_name AS region_name
FROM 
    TopSales ts
LEFT JOIN 
    SupplierDetails sd ON ts.p_partkey = sd.s_nationkey
LEFT JOIN 
    nation n ON sd.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ts.total_sales > 50000
ORDER BY 
    ts.sales_category, ts.total_sales DESC;