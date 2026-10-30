WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice AS price,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
)
SELECT 
    rc.c_name,
    rc.total_spent,
    ps.s_name AS supplier_name,
    pd.p_name AS product_name, 
    pd.price,
    pd.total_sales,
    pd.total_quantity,
    CASE 
        WHEN pd.total_sales > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_loss_status
FROM 
    RankedCustomers rc
JOIN 
    orders o ON rc.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    ProductDetails pd ON l.l_partkey = pd.p_partkey
LEFT JOIN 
    SupplierStats ps ON l.l_suppkey = ps.s_suppkey 
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.total_spent DESC, total_sales DESC;