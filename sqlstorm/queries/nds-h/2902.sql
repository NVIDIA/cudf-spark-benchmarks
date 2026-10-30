
WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        n.n_name
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSales AS (
    SELECT 
        nation_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
    WHERE 
        total_sales > 10000
)
SELECT 
    rs.nation_name,
    rs.total_sales,
    sd.s_name,
    sd.total_cost
FROM 
    RankedSales rs
LEFT JOIN 
    SupplierDetails sd ON sd.total_cost = (
        SELECT 
            MAX(total_cost) 
        FROM 
            SupplierDetails 
        WHERE 
            total_cost < (SELECT AVG(total_cost) FROM SupplierDetails)
    )
WHERE 
    rs.sales_rank <= 5
ORDER BY 
    rs.total_sales DESC;
