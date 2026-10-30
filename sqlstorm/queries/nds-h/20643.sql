WITH OrderedSales AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'P') 
        AND l.l_quantity > 0
    GROUP BY 
        o.o_orderkey
),
FilteredSales AS (
    SELECT 
        os.o_orderkey,
        os.total_sales,
        os.unique_parts,
        COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name
    FROM 
        OrderedSales os
    LEFT JOIN 
        partsupp ps ON os.o_orderkey = ps.ps_partkey 
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        os.total_sales > 1000
        OR os.unique_parts > 5
)
SELECT 
    fs.o_orderkey,
    fs.total_sales, 
    fs.unique_parts, 
    CASE 
        WHEN fs.supplier_name IS NULL THEN 'No Supplier' 
        ELSE fs.supplier_name 
    END AS supplier_info,
    COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returned_items,
    SUM(l.l_quantity) FILTER (WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-10-01') AS total_quantity_shipped,
    max(fs.unique_parts) OVER (PARTITION BY fs.total_sales) AS max_unique_parts_in_sales_group
FROM 
    FilteredSales fs
JOIN 
    lineitem l ON fs.o_orderkey = l.l_orderkey
GROUP BY 
    fs.o_orderkey, fs.total_sales, fs.unique_parts, fs.supplier_name
HAVING 
    fs.unique_parts > (SELECT AVG(unique_parts) FROM FilteredSales) 
    OR COUNT(l.l_orderkey) > 3
ORDER BY 
    fs.total_sales DESC, fs.o_orderkey ASC;