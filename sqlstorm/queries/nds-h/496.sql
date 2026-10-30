
WITH SalesSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        r.r_name AS supplier_region
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > (
            SELECT 
                AVG(s_acctbal) 
            FROM 
                supplier 
            WHERE 
                s_acctbal IS NOT NULL
        )
),
FinalResult AS (
    SELECT 
        ss.c_custkey,
        ss.c_name,
        ss.total_sales,
        tc.s_name AS high_balance_supplier,
        tc.s_acctbal,
        tc.supplier_region
    FROM 
        SalesSummary ss
    LEFT JOIN 
        TopCustomers tc ON ss.c_custkey = (
            SELECT 
                c.c_custkey 
            FROM 
                customer c 
            JOIN 
                orders o ON c.c_custkey = o.o_custkey 
            WHERE 
                o.o_orderkey IN (
                    SELECT 
                        l.l_orderkey 
                    FROM 
                        lineitem l 
                    WHERE 
                        l.l_discount > 0.05
                )
            LIMIT 1
        )
    WHERE 
        ss.rank <= 10
)

SELECT 
    fr.c_custkey,
    fr.c_name,
    fr.total_sales,
    fr.high_balance_supplier,
    COALESCE(fr.s_acctbal, 0) AS supplier_acctbal,
    fr.supplier_region
FROM 
    FinalResult fr
WHERE 
    fr.supplier_region IS NOT NULL
ORDER BY 
    fr.total_sales DESC;
