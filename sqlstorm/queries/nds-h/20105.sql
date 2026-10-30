
WITH RankedLineItems AS (
    SELECT 
        l_orderkey,
        l_partkey,
        l_suppkey,
        l_quantity,
        l_extendedprice,
        l_discount,
        l_tax,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY l_extendedprice DESC) AS rn
    FROM 
        lineitem
    WHERE 
        l_shipdate >= '1997-01-01'
        AND l_returnflag = 'N'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * pl.l_quantity) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * pl.l_quantity) DESC) AS nation_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedLineItems pl ON ps.ps_partkey = pl.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name
    FROM 
        SupplierDetails sd
    WHERE 
        sd.nation_rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_name,
    co.total_spent,
    co.order_count,
    COALESCE(t.s_name, 'No Supplier') AS top_supplier,
    CASE 
        WHEN co.last_order_date IS NULL THEN 'Never Ordered'
        WHEN co.last_order_date >= DATE '1998-10-01' - INTERVAL '30 days' THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status
FROM 
    CustomerOrders co
LEFT JOIN 
    TopSuppliers t ON co.c_custkey IN (SELECT DISTINCT ps.ps_supplycost 
                                          FROM partsupp ps 
                                          JOIN lineitem li ON ps.ps_partkey = li.l_partkey 
                                          WHERE li.l_discount > 0.1)
ORDER BY 
    co.total_spent DESC, 
    customer_status;
