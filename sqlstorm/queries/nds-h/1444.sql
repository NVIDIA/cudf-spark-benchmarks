WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        st.total_avail_qty, 
        st.avg_supply_cost,
        ROW_NUMBER() OVER (ORDER BY st.total_avail_qty DESC) AS rk
    FROM 
        SupplierStats st
    JOIN 
        supplier s ON st.s_suppkey = s.s_suppkey
    WHERE 
        st.total_avail_qty > (SELECT AVG(total_avail_qty) FROM SupplierStats)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    COALESCE(os.total_spent, 0) AS total_spent,
    COALESCE(ts.total_avail_qty, 0) AS total_available_qty,
    ts.avg_supply_cost
FROM 
    CustomerOrders cs
LEFT JOIN 
    TopSuppliers ts ON ts.rk <= 5
LEFT JOIN 
    (SELECT 
         o.o_custkey,
         SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
     FROM 
         lineitem l
     JOIN 
         orders o ON l.l_orderkey = o.o_orderkey
     GROUP BY 
         o.o_custkey) os ON cs.c_custkey = os.o_custkey
WHERE 
    cs.order_count > 0
ORDER BY 
    total_spent DESC, cs.c_name ASC;
