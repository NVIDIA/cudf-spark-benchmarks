WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER(PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey,
        ps.ps_suppkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey,
        c.c_name,
        n.n_name
)
SELECT 
    rd.o_orderkey,
    cd.c_name AS customer_name,
    cd.nation_name,
    sp.total_availqty,
    sp.avg_supplycost,
    CASE 
        WHEN sp.total_availqty IS NULL THEN 'No Available Stock' 
        ELSE 'In Stock' 
    END AS stock_status,
    CASE 
        WHEN cd.total_spent > 1000 THEN 'High Value Customer' 
        ELSE 'Regular Customer' 
    END AS customer_value_category
FROM 
    RankedOrders rd
JOIN 
    CustomerDetails cd ON rd.o_orderkey = cd.c_custkey
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey = rd.o_orderkey
WHERE 
    cd.total_spent IS NOT NULL
    AND sp.avg_supplycost < 50 
    AND EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_orderkey = rd.o_orderkey 
        AND l.l_discount > 0.1
    )
ORDER BY 
    rd.o_orderdate DESC, 
    cd.total_spent DESC
LIMIT 100;