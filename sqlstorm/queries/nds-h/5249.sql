
WITH TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate < DATE '1996-01-01'
    GROUP BY 
        l.l_orderkey
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(ts.total_amount) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        TotalSales ts ON o.o_orderkey = ts.l_orderkey
    GROUP BY 
        c.c_custkey
),
RankedCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSales cs
)
SELECT 
    n.n_name AS nation,
    rc.total_spent,
    rc.rank
FROM 
    RankedCustomers rc
JOIN 
    customer c ON rc.c_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.total_spent DESC;
