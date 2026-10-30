WITH RankedSales AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), TopProducts AS (
    SELECT * 
    FROM RankedSales 
    WHERE sales_rank <= 5
), SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS supply_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, s.s_acctbal
    HAVING 
        COUNT(ps.ps_partkey) > 2
), CompositeSales AS (
    SELECT 
        t.p_partkey,
        t.p_name,
        t.total_sales,
        COALESCE(SUM(sd.s_acctbal), 0) AS total_supplier_balance,
        CASE 
            WHEN COUNT(DISTINCT sd.s_suppkey) > 5 THEN 'High Supp Count' 
            ELSE 'Normal Supp Count' 
        END AS supplier_status
    FROM 
        TopProducts t
    LEFT JOIN 
        SupplierDetails sd ON t.p_partkey = sd.s_suppkey
    GROUP BY 
        t.p_partkey, t.p_name, t.total_sales
), FinalResult AS (
    SELECT 
        cs.p_partkey,
        cs.p_name,
        cs.total_sales,
        cs.total_supplier_balance,
        cs.supplier_status,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS rank_sales
    FROM 
        CompositeSales cs
)
SELECT 
    fr.p_partkey,
    fr.p_name,
    fr.total_sales,
    fr.total_supplier_balance,
    fr.supplier_status,
    CASE 
        WHEN fr.rank_sales <= 3 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_category
FROM 
    FinalResult fr
WHERE 
    fr.total_supplier_balance IS NOT NULL 
    AND fr.total_sales > (
        SELECT AVG(total_sales) FROM CompositeSales
    )
ORDER BY 
    fr.rank_sales;
