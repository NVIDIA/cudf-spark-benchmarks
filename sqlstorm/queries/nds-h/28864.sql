WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_name LIKE 'Small%'
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        COUNT(r.r_regionkey) AS region_count, 
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name, 
    r.region_count, 
    r.total_acctbal, 
    CONCAT('Total Account Balance for Top Suppliers in ', r.r_name, ' is ', CAST(r.total_acctbal AS varchar(50))) AS formatted_balance
FROM 
    TopSuppliers r
ORDER BY 
    r.total_acctbal DESC;
